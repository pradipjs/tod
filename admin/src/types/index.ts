// Multilingual text type for content in multiple languages
export type MultilingualText = Record<string, string>;

// Age group constants
export const AGE_GROUPS = ['kids', 'teen', 'adults'] as const;
export type AgeGroup = typeof AGE_GROUPS[number];

// Language constants
export const LANGUAGES = ['en', 'zh', 'es', 'hi', 'ar', 'fr', 'pt', 'bn', 'ru', 'ur'] as const;
export type Language = typeof LANGUAGES[number];

export const LANGUAGE_NAMES: Record<Language, string> = {
    en: 'English',
    zh: 'Chinese',
    es: 'Spanish',
    hi: 'Hindi',
    ar: 'Arabic',
    fr: 'French',
    pt: 'Portuguese',
    bn: 'Bengali',
    ru: 'Russian',
    ur: 'Urdu',
};

// Task type constants
export const TASK_TYPES = ['truth', 'dare'] as const;
export type TaskType = typeof TASK_TYPES[number];

// Category type
export interface Category {
    id: string;
    emoji: string;
    age_group: AgeGroup;
    label: MultilingualText;
    requires_consent: boolean;
    is_active: boolean;
    sort_order: number;
    created_at: string;
    updated_at: string;
}

// Task type
export interface Task {
    id: string;
    category_id: string;
    category?: Category;
    type: TaskType;
    text: string;
    language: Language;
    created_at: string;
    updated_at: string;
}

// Create/Update DTOs
export interface CreateCategoryDto {
    emoji: string;
    age_group: AgeGroup;
    label: MultilingualText;
    requires_consent: boolean;
    is_active: boolean;
    sort_order: number;
}

export interface CreateTaskDto {
    category_id: string;
    type: TaskType;
    text: string;
    language: Language;
}

// API response types
export interface PaginatedResponse<T> {
    data: T[];
    total: number;
    page: number;
    page_size: number;
    total_pages: number;
}

export interface ErrorResponse {
    error: string;
    message: string;
}

export interface SuccessResponse {
    success: boolean;
    message: string;
}

// Generate tasks response with detailed counts
export interface GenerateTasksResponse {
    success: boolean;
    message: string;
    tasks_created: number;
    total_truths_count: number;
    total_dares_count: number;
    combinations_count: number;
}

// Generate request type - null values mean "all"
export interface GenerateRequest {
    age_group: AgeGroup | null;
    category_id: string | null;
    language: Language | null;
    count: number;
}

// Filter types
export interface CategoryFilter {
    age_groups?: AgeGroup[];
    active?: boolean;
}

export interface TaskFilter {
    category_ids?: string[];
    types?: TaskType[];
    language?: Language;
    languages?: Language[];
    page?: number;
    page_size?: number;
}
