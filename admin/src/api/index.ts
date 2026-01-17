import axios, { AxiosError, type AxiosInstance, type InternalAxiosRequestConfig } from 'axios';
import {
    AGE_GROUPS,
    type AgeGroup,
    type Category,
    type CategoryFilter,
    type CreateCategoryDto,
    type CreateTaskDto,
    type GenerateRequest,
    type Language,
    LANGUAGES,
    type PaginatedResponse,
    type SuccessResponse,
    type Task,
    type TaskFilter,
} from '../types';

const API_BASE_URL = (import.meta.env.VITE_API_URL || 'http://localhost:8080') + '/api/v1';

// Create axios instance
const api: AxiosInstance = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Auth token storage
let authToken: string | null = localStorage.getItem('admin_otp');

// Add auth interceptor
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
    if (authToken && config.headers) {
        config.headers['X-Admin-OTP'] = authToken;
    }
    return config;
});

// Auth functions
export const setAuthToken = (token: string) => {
    authToken = token;
    localStorage.setItem('admin_otp', token);
};

export const clearAuthToken = () => {
    authToken = null;
    localStorage.removeItem('admin_otp');
};

export const getAuthToken = () => authToken;

// API error handler
export const handleApiError = (error: unknown): string => {
    if (error instanceof AxiosError) {
        if (error.response?.status === 401) {
            clearAuthToken();
            window.location.href = '/login';
            return 'Unauthorized. Please login again.';
        }
        return error.response?.data?.message || error.message;
    }
    return 'An unexpected error occurred';
};

// ============ AUTH APIs ============

export const verifyAuth = async (): Promise<boolean> => {
    try {
        await api.get('/auth/verify');
        return true;
    } catch {
        return false;
    }
};

// ============ LANGUAGE APIs ============

export const getLanguages = async (): Promise<{ code: Language; name: string }[]> => {
    const response = await api.get<{ languages: { code: Language; name: string }[] }>('/languages');
    return response.data.languages;
};

export const getAgeGroups = async (): Promise<{ value: AgeGroup; label: string; min_age: number; max_age: number }[]> => {
    const response = await api.get<{ age_groups: { value: AgeGroup; label: string; min_age: number; max_age: number }[] }>('/age-groups');
    return response.data.age_groups;
};

// Static versions (fallback)
export const getStaticLanguages = () => LANGUAGES.map(code => ({ code, name: code }));
export const getStaticAgeGroups = () => AGE_GROUPS.map(value => ({ value, label: value }));

// ============ CATEGORY APIs ============

export const getCategories = async (filter?: CategoryFilter): Promise<Category[]> => {
    const params = new URLSearchParams();
    if (filter?.age_groups?.length) {
        params.set('age_groups', filter.age_groups.join(','));
    }
    if (filter?.active !== undefined) {
        params.set('active', String(filter.active));
    }

    const response = await api.get<{ data: Category[] }>(`/categories?${params.toString()}`);
    return response.data.data;
};

export const getCategoryById = async (id: string): Promise<Category> => {
    const response = await api.get<Category>(`/categories/${id}`);
    return response.data;
};

export const createCategory = async (data: CreateCategoryDto): Promise<Category> => {
    const response = await api.post<Category>('/categories', data);
    return response.data;
};

export const updateCategory = async (id: string, data: Partial<CreateCategoryDto>): Promise<Category> => {
    const response = await api.put<Category>(`/categories/${id}`, data);
    return response.data;
};

export const deleteCategory = async (id: string): Promise<SuccessResponse> => {
    const response = await api.delete<SuccessResponse>(`/categories/${id}`);
    return response.data;
};

export const getCategoryCount = async (filter?: CategoryFilter): Promise<number> => {
    const params = new URLSearchParams();
    if (filter?.age_groups?.length) {
        params.set('age_groups', filter.age_groups.join(','));
    }
    if (filter?.active !== undefined) {
        params.set('active', String(filter.active));
    }

    const response = await api.get<{ count: number }>(`/categories/count?${params.toString()}`);
    return response.data.count;
};

// ============ TASK APIs ============

export const getTasks = async (filter?: TaskFilter): Promise<PaginatedResponse<Task>> => {
    const params = new URLSearchParams();
    if (filter?.category_ids?.length) {
        params.set('category_ids', filter.category_ids.join(','));
    }
    if (filter?.age_groups?.length) {
        params.set('age_groups', filter.age_groups.join(','));
    }
    if (filter?.types?.length) {
        params.set('types', filter.types.join(','));
    }
    if (filter?.languages?.length) {
        params.set('languages', filter.languages.join(','));
    }
    if (filter?.active !== undefined) {
        params.set('active', String(filter.active));
    }
    if (filter?.page !== undefined) {
        params.set('offset', String((filter.page - 1) * (filter.page_size || 20)));
    }
    if (filter?.page_size !== undefined) {
        params.set('limit', String(filter.page_size));
    }

    const response = await api.get<PaginatedResponse<Task>>(`/tasks?${params.toString()}`);
    return response.data;
};

export const getTaskById = async (id: string): Promise<Task> => {
    const response = await api.get<Task>(`/tasks/${id}`);
    return response.data;
};

export const createTask = async (data: CreateTaskDto): Promise<Task> => {
    const response = await api.post<Task>('/tasks', data);
    return response.data;
};

export const updateTask = async (id: string, data: Partial<CreateTaskDto>): Promise<Task> => {
    const response = await api.put<Task>(`/tasks/${id}`, data);
    return response.data;
};

export const deleteTask = async (id: string): Promise<SuccessResponse> => {
    const response = await api.delete<SuccessResponse>(`/tasks/${id}`);
    return response.data;
};

export const getTaskCount = async (filter?: TaskFilter): Promise<number> => {
    const params = new URLSearchParams();
    if (filter?.category_ids?.length) {
        params.set('category_ids', filter.category_ids.join(','));
    }
    if (filter?.types?.length) {
        params.set('types', filter.types.join(','));
    }
    if (filter?.active !== undefined) {
        params.set('active', String(filter.active));
    }

    const response = await api.get<{ count: number }>(`/tasks/count?${params.toString()}`);
    return response.data.count;
};

// ============ GENERATE API ============

export const generateTasks = async (data: GenerateRequest): Promise<SuccessResponse> => {
    const response = await api.post<SuccessResponse>('/generate', data);
    return response.data;
};

/**
 * Generate category labels request type
 */
export interface GenerateCategoryLabelsRequest {
    /** Category name in English */
    category_name: string;
    /** Optional list of language codes to translate to */
    languages?: string[];
}

/**
 * Generate category labels response type
 */
export interface GenerateCategoryLabelsResponse {
    success: boolean;
    labels: Record<string, string>;
}

/**
 * Generate multilingual labels for a category name using AI
 * @param categoryName - The English category name to translate
 * @param languages - Optional array of language codes (defaults to all supported languages)
 * @returns Multilingual labels object
 */
export const generateCategoryLabels = async (
    categoryName: string,
    languages?: string[]
): Promise<GenerateCategoryLabelsResponse> => {
    const response = await api.post<GenerateCategoryLabelsResponse>('/generate/category-labels', {
        category_name: categoryName,
        languages,
    });
    return response.data;
};

export default api;
