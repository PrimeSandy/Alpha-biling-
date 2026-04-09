const { Anthropic } = require('@anthropic-ai/sdk');
const { GoogleGenerativeAI } = require('@google/generative-ai');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { image, provider, apiKey } = req.body;

  if (!image || !provider) {
    return res.status(400).json({ error: 'Missing image or provider' });
  }

  const key = apiKey || (provider === 'claude' ? process.env.ANTHROPIC_API_KEY : process.env.GEMINI_API_KEY);

  if (!key) {
    return res.status(400).json({ error: 'API Key is missing' });
  }

  try {
    if (provider === 'claude') {
      const anthropic = new Anthropic({ apiKey: key });
      const response = await anthropic.messages.create({
        model: "claude-3-sonnet-20240229",
        max_tokens: 1000,
        messages: [{
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } },
            { type: "text", text: "Extract all line items from this bill. Return ONLY a valid JSON array. Format: [{\"id\":\"1\",\"name\":\"Item name\",\"unitPrice\":120,\"quantity\":1}]. Keep tax/GST/Service Charge as separate items. If an item is a discount, use a negative unitPrice." }
          ]
        }]
      });
      const text = response.content[0].text;
      const cleaned = text.replace(/```json/g, '').replace(/```/g, '').trim();
      return res.status(200).send(cleaned);
    } else if (provider === 'gemini') {
      const genAI = new GoogleGenerativeAI(key);
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
      const result = await model.generateContent([
        "Extract all line items from this bill. Return ONLY a valid JSON array. Format: [{\"id\":\"1\",\"name\":\"Item name\",\"unitPrice\":120,\"quantity\":1}]. Keep tax/GST/Service Charge as separate items. If an item is a discount, use a negative unitPrice.",
        { inlineData: { data: image, mimeType: "image/jpeg" } }
      ]);
      const text = result.response.text();
      const cleaned = text.replace(/```json/g, '').replace(/```/g, '').trim();
      return res.status(200).send(cleaned);
    } else {
      return res.status(400).json({ error: 'Invalid provider' });
    }
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: error.message });
  }
};
