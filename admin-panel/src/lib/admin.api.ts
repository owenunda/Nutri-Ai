import { api } from './api';
import { buildParams } from './events.api';
import type { ApiResponse } from '../types/auth';
import type { Overview, Plan, Role, UserDetail, UserFilters, UserListResponse } from '../types/admin';

export async function fetchOverview(days: number): Promise<Overview> {
  const { data } = await api.get<ApiResponse<Overview>>('/admin/overview', { params: { days } });
  return data.data;
}

export async function fetchUsers(filters: UserFilters): Promise<UserListResponse> {
  const { data } = await api.get<ApiResponse<UserListResponse>>('/admin/users', {
    params: buildParams(filters),
  });
  return data.data;
}

export async function fetchUserDetail(userId: number): Promise<UserDetail> {
  const { data } = await api.get<ApiResponse<UserDetail>>(`/admin/users/${userId}`);
  return data.data;
}

export async function updateUserPlan(userId: number, plan: Plan): Promise<{ userId: number; plan: Plan }> {
  const { data } = await api.patch<ApiResponse<{ userId: number; plan: Plan }>>(
    `/admin/users/${userId}/plan`,
    { plan }
  );
  return data.data;
}

export async function updateUserPassword(userId: number, password: string): Promise<{ userId: number }> {
  const { data } = await api.patch<ApiResponse<{ userId: number }>>(
    `/admin/users/${userId}/password`,
    { password }
  );
  return data.data;
}

export async function updateUserRole(userId: number, role: Role): Promise<{ userId: number; role: Role }> {
  const { data } = await api.patch<ApiResponse<{ userId: number; role: Role }>>(
    `/admin/users/${userId}/role`,
    { role }
  );
  return data.data;
}
