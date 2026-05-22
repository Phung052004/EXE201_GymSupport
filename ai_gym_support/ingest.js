import { Pinecone } from "@pinecone-database/pinecone";
import { GoogleGenAI } from "@google/genai";
import { RecursiveCharacterTextSplitter } from "@langchain/textsplitters";
import fs from "fs";
import "dotenv/config";

async function run() {
  try {
    console.log("1. Đang đọc file tailieu.txt...");
    const text = fs.readFileSync("tailieu.txt", "utf-8");

    console.log("2. Đang cắt nhỏ văn bản...");
    const textSplitter = new RecursiveCharacterTextSplitter({
      chunkSize: 200,
      chunkOverlap: 20,
    });
    const docs = await textSplitter.createDocuments([text]);
    console.log(`-> Đã cắt thành ${docs.length} đoạn nhỏ.`);

    console.log("3. Khởi tạo SDK Google và Pinecone...");
    const ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
      apiVersion: "v1",
    });

    const pinecone = new Pinecone({ apiKey: process.env.PINECONE_API_KEY });
    const pineconeIndex = pinecone.index(process.env.PINECONE_INDEX_NAME);

    console.log("4. Đang tiến hành Embedding và Upsert lên Pinecone...");

    const vectors = [];
    const chunkTexts = docs.map((doc) => doc.pageContent);
    const result = await ai.models.embedContent({
      model: "gemini-embedding-001",
      contents: chunkTexts,
      config: {
        taskType: "RETRIEVAL_DOCUMENT",
        outputDimensionality: 768,
      },
    });
    const embeddingsList = result.embeddings.map(
      (embedding) => embedding.values || [],
    );

    for (let i = 0; i < docs.length; i++) {
      const chunkText = chunkTexts[i];
      const embedding = embeddingsList[i];
      console.log(
        `-> Đã tạo Vector cho đoạn ${i + 1}/${docs.length} (Độ dài: ${embedding.length})`,
      );

      // Cấu trúc lại dữ liệu theo format Pinecone yêu cầu
      vectors.push({
        id: `chunk-id-${i}-${Date.now()}`, // Tạo ID duy nhất cho mỗi đoạn
        values: embedding, // Mảng 768 con số
        metadata: { text: chunkText }, // Lưu text gốc đi kèm để sau này AI đọc
      });
    }

    console.log("5. Đang đẩy dữ liệu lên Pinecone Database...");
    await pineconeIndex.upsert(vectors);

    console.log("✅ HOÀN TẤT THÀNH CÔNG! Dữ liệu đã nằm yên vị trên Pinecone.");
  } catch (error) {
    console.error("❌ Có lỗi xảy ra:", error);
  }
}

run();
