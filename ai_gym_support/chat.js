import { Pinecone } from "@pinecone-database/pinecone";
import { GoogleGenAI } from "@google/genai";
import "dotenv/config";

async function askAI(question) {
  try {
    const ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
    });

    const pinecone = new Pinecone({ apiKey: process.env.PINECONE_API_KEY });
    const pineconeIndex = pinecone.index(process.env.PINECONE_INDEX_NAME);

    console.log(`\n🔍 Câu hỏi của bạn: "${question}"`);
    console.log("-> Đang chuyển câu hỏi thành Vector...");

    const embeddingResult = await ai.models.embedContent({
      model: "gemini-embedding-001",
      contents: [question],
      config: {
        taskType: "RETRIEVAL_QUERY",
        outputDimensionality: 768,
      },
    });
    const questionVector = embeddingResult.embeddings[0].values;

    console.log("-> Đang lục tìm tài liệu liên quan trên Pinecone...");

    const queryResponse = await pineconeIndex.query({
      vector: questionVector,
      topK: 2,
      includeMetadata: true,
    });

    const contexts = queryResponse.matches.map((match) => match.metadata.text);
    const contextText = contexts.join("\n---\n");

    console.log("-> Đang nhờ Gemini phân tích tài liệu và trả lời...");

    const systemPrompt = `
      Bạn là trợ lý ảo thông minh. Hãy trả lời câu hỏi của người dùng một cách chính xác dựa trên tài liệu tham khảo được cung cấp dưới đây.
      Nếu trong tài liệu không có thông tin để trả lời, hãy nói: "Tôi không tìm thấy thông tin này trong tài liệu được cung cấp". Tuyệt đối không tự bịa thông tin.

      Tài liệu tham khảo:
      ${contextText}
    `;

    // TÊN MODEL ĐÃ ĐƯỢC CHUẨN HÓA, KHÔNG CHỨA KHOẢNG TRẮNG HAY TIỀN TỐ LẠ
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: `${systemPrompt}\n\nCâu hỏi: ${question}`,
    });

    console.log("\n🤖 AI TRẢ LỜI:");
    console.log("=========================================");
    console.log(response.text);
    console.log("=========================================\n");
  } catch (error) {
    console.error("❌ Có lỗi xảy ra khi chat:", error);
  }
}

askAI(
  "Trường FPT cơ sở Hồ Chí Minh nằm ở đâu và mã ngành kỹ thuật phần mềm là gì?",
);
