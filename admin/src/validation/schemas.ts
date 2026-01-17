import { z } from 'zod';

// Age group validation
export const ageGroups = ['kids', 'teen', 'adults'] as const;
export type AgeGroup = (typeof ageGroups)[number];

// Task type validation
export const taskTypes = ['truth', 'dare'] as const;
export type TaskType = (typeof taskTypes)[number];

// Language code validation
export const languageCodes = ['en', 'zh', 'es', 'hi', 'ar', 'fr', 'pt', 'bn', 'ru', 'ur'] as const;
export type LanguageCode = (typeof languageCodes)[number];

// Multilingual text schema - requires at least English
export const multilingualTextSchema = z.object({
    en: z.string().min(1, 'English text is required'),
}).catchall(z.string().optional());

// Category form schema
export const categoryFormSchema = z.object({
    emoji: z.string().min(1, 'Emoji is required').max(10, 'Emoji is too long'),
    age_group: z.enum(ageGroups, { message: 'Please select a valid age group' }),
    label: multilingualTextSchema,
    requires_consent: z.boolean(),
    is_active: z.boolean(),
    sort_order: z.number().min(0, 'Sort order must be 0 or greater'),
});

export type CategoryFormData = z.infer<typeof categoryFormSchema>;

// Task form schema
export const taskFormSchema = z.object({
    category_id: z.string().uuid('Please select a valid category'),
    type: z.enum(taskTypes, { message: 'Please select truth or dare' }),
    text: multilingualTextSchema,
    hint: z.object({
        en: z.string().optional(),
    }).catchall(z.string().optional()).optional(),
    min_age: z.number().min(0, 'Minimum age must be 0 or greater').max(99, 'Invalid age'),
    requires_consent: z.boolean(),
    is_active: z.boolean(),
});

export type TaskFormData = z.infer<typeof taskFormSchema>;

// Generate tasks request schema
export const generateTasksSchema = z.object({
    category_id: z.string().uuid('Please select a valid category'),
    type: z.enum(taskTypes, { message: 'Please select truth or dare' }),
    count: z.number().min(1, 'At least 1 task required').max(50, 'Maximum 50 tasks at a time'),
    languages: z.array(z.enum(languageCodes)).min(1, 'Select at least one language'),
    custom_prompt: z.string().max(500, 'Custom prompt is too long').optional(),
});

export type GenerateTasksFormData = z.infer<typeof generateTasksSchema>;

// Login schema
export const loginSchema = z.object({
    otp: z.string().min(1, 'OTP key is required').min(6, 'OTP key must be at least 6 characters'),
});

export type LoginFormData = z.infer<typeof loginSchema>;
