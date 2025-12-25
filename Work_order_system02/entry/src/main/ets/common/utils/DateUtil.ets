/**
 * 日期时间工具类
 */

/**
 * 格式化日期时间
 * @param dateString ISO格式的日期字符串
 * @returns 格式化后的日期时间字符串
 */
export function formatDateTime(dateString: string): string {
  if (!dateString) {
    return '';
  }

  try {
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}`;
  } catch (err) {
    console.error('Date format error:', JSON.stringify(err));
    return dateString;
  }
}

/**
 * 获取当前时间（ISO格式）
 */
export function getCurrentTime(): string {
  return new Date().toISOString();
}

/**
 * 格式化日期（不包含时间）
 */
export function formatDate(dateString: string): string {
  if (!dateString) {
    return '';
  }

  try {
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
  } catch (err) {
    console.error('Date format error:', JSON.stringify(err));
    return dateString;
  }
}



