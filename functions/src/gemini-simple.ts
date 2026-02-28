/**
 * Simple Gemini client using VertexAI SDK
 */

import { VertexAI, HarmCategory, HarmBlockThreshold } from '@google-cloud/vertexai';

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-74a5d';
const LOCATION = 'us-central1';

const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });

export interface GenerationConfig {
  temperature?: number;
  maxOutputTokens?: number;
  topP?: number;
  topK?: number;
  responseMimeType?: string;
}

export async function generateTextWithImage(
  base64Image: string,
  mimeType: string,
  prompt: string,
  systemInstruction: string,
  config?: GenerationConfig
): Promise<string> {
  const model = vertexAI.getGenerativeModel({
    model: 'gemini-2.0-flash-001',
    systemInstruction: {
      role: 'system',
      parts: [{ text: systemInstruction }],
    },
    safetySettings: [
      {
        category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
        threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
      },
    ],
    generationConfig: config,
  });

  const result = await model.generateContent({
    contents: [
      {
        role: 'user',
        parts: [
          {
            inlineData: {
              mimeType,
              data: base64Image,
            },
          },
          { text: prompt },
        ],
      },
    ],
  });

  const response = result.response;
  return response.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

export async function generateText(
  prompt: string,
  systemInstruction: string,
  config?: GenerationConfig
): Promise<string> {
  const model = vertexAI.getGenerativeModel({
    model: 'gemini-2.0-flash-001',
    systemInstruction: {
      role: 'system',
      parts: [{ text: systemInstruction }],
    },
    safetySettings: [
      {
        category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
        threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
      },
    ],
    generationConfig: config,
  });

  const result = await model.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
  });

  const response = result.response;
  return response.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

export async function generateJSONWithImages<T>(
  images: Array<{ data: string; mimeType: string }>,
  prompt: string,
  systemInstruction: string,
  config?: GenerationConfig
): Promise<T> {
  const text = await generateTextWithImages(
    images,
    prompt,
    systemInstruction,
    { ...config, responseMimeType: 'application/json' }
  );
  return JSON.parse(text);
}

export async function generateTextWithImages(
  images: Array<{ data: string; mimeType: string }>,
  prompt: string,
  systemInstruction: string,
  config?: GenerationConfig
): Promise<string> {
  const model = vertexAI.getGenerativeModel({
    model: 'gemini-2.0-flash-001',
    systemInstruction: {
      role: 'system',
      parts: [{ text: systemInstruction }],
    },
    safetySettings: [
      {
        category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
        threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
      },
    ],
    generationConfig: config,
  });

  const parts = images.map(img => ({
    inlineData: { data: img.data, mimeType: img.mimeType }
  }));
  parts.push({ text: prompt } as any);

  const result = await model.generateContent({
    contents: [{ role: 'user', parts: parts as any }],
  });

  const response = result.response;
  return response.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

export async function generateJSON<T>(
  prompt: string,
  systemInstruction: string,
  config?: GenerationConfig
): Promise<T> {
  const text = await generateText(prompt, systemInstruction, {
    ...config,
    responseMimeType: 'application/json',
  });
  return JSON.parse(text);
}
