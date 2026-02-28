/**
 * Gemini API Client for Juris
 *
 * Direct integration with Generative Language API using REST
 * to avoid Vertex AI SDK model path issues.
 */

import { GoogleAuth } from 'google-auth-library';

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-74a5d';
const GEMINI_LOCATION = 'us-central1'; // Gemini 1.5 Pro only available in us-central1

// Initialize Google Auth for service account
const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

export interface GeminiGenerationConfig {
  temperature?: number;
  maxOutputTokens?: number;
  topP?: number;
  topK?: number;
  responseMimeType?: string;
}

export interface GeminiContent {
  role?: 'user' | 'model' | 'system';
  parts: Array<{
    text?: string;
    inlineData?: {
      mimeType: string;
      data: string; // base64
    };
  }>;
}

export interface GeminiRequest {
  contents: GeminiContent[];
  systemInstruction?: {
    role?: string;
    parts: Array<{ text: string }>;
  };
  generationConfig?: GeminiGenerationConfig;
}

export interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string;
      }>;
    };
    finishReason?: string;
    safetyRatings?: Array<{
      category: string;
      probability: string;
    }>;
  }>;
  promptFeedback?: {
    blockReason?: string;
    safetyRatings?: Array<{
      category: string;
      probability: string;
    }>;
  };
}

/**
 * Call Gemini 1.5 Pro via Generative Language API.
 * Uses direct REST API to avoid Vertex AI SDK model path issues.
 */
export async function callGemini(request: GeminiRequest): Promise<GeminiResponse> {
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();

  if (!accessToken.token) {
    throw new Error('Failed to get access token');
  }

  // Use Vertex AI endpoint for Gemini (supports service account auth)
  // Use specific model version that's generally available
  const endpoint = `https://${GEMINI_LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${GEMINI_LOCATION}/publishers/google/models/gemini-2.0-flash-001:generateContent`;

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(request),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `Gemini API request failed: ${response.status} ${response.statusText}\n${errorText}`
    );
  }

  return response.json();
}

/**
 * Helper: Generate content with text-only input.
 */
export async function generateText(
  prompt: string,
  systemPrompt?: string,
  config?: GeminiGenerationConfig
): Promise<string> {
  const request: GeminiRequest = {
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: config || {
      temperature: 0.2,
      maxOutputTokens: 8192,
    },
  };

  if (systemPrompt) {
    request.systemInstruction = {
      role: 'system',
      parts: [{ text: systemPrompt }],
    };
  }

  const response = await callGemini(request);
  const text = response.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!text) {
    throw new Error('Gemini returned empty response');
  }

  return text;
}

/**
 * Helper: Generate content with multiple images + text input (for OCR).
 */
export async function generateWithImages(
  images: Array<{ data: string; mimeType: string }>,
  textPrompt: string,
  systemPrompt?: string,
  config?: GeminiGenerationConfig
): Promise<string> {
  const parts: GeminiContent['parts'] = images.map((img) => ({
    inlineData: {
      mimeType: img.mimeType,
      data: img.data,
    },
  }));
  parts.push({ text: textPrompt });

  const request: GeminiRequest = {
    contents: [
      {
        role: 'user',
        parts,
      },
    ],
    generationConfig: config || {
      temperature: 0.1,
      maxOutputTokens: 8192,
    },
  };

  if (systemPrompt) {
    request.systemInstruction = {
      role: 'system',
      parts: [{ text: systemPrompt }],
    };
  }

  const response = await callGemini(request);
  const text = response.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!text) {
    throw new Error('Gemini returned empty response for image input');
  }

  return text;
}

/**
 * Helper: Generate JSON output with schema validation.
 */
export async function generateJSON<T>(
  prompt: string,
  systemPrompt?: string,
  config?: Omit<GeminiGenerationConfig, 'responseMimeType'>
): Promise<T> {
  const text = await generateText(prompt, systemPrompt, {
    ...config,
    responseMimeType: 'application/json',
  });

  try {
    return JSON.parse(text) as T;
  } catch (error) {
    throw new Error(`Failed to parse Gemini JSON response: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Helper: Generate JSON output with multiple images input.
 */
export async function generateJSONWithImages<T>(
  images: Array<{ data: string; mimeType: string }>,
  textPrompt: string,
  systemPrompt?: string,
  config?: Omit<GeminiGenerationConfig, 'responseMimeType'>
): Promise<T> {
  const text = await generateWithImages(images, textPrompt, systemPrompt, {
    ...config,
    responseMimeType: 'application/json',
  });

  try {
    return JSON.parse(text) as T;
  } catch (error) {
    throw new Error(`Failed to parse Gemini JSON response: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
