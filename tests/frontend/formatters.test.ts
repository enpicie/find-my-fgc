import { describe, it, expect } from 'vitest';
import { formatDate, formatList } from '../../frontend/utils/formatters';

describe('formatters', () => {
  describe('formatDate', () => {
    it('should format a unix timestamp correctly', () => {
      const timestamp = "1715856000";
      const result = formatDate(timestamp);
      expect(result).toContain('May 16, 2024');
    });
  });

  describe('formatList', () => {
    it('should return empty string for undefined input', () => {
      expect(formatList(undefined)).toBe('');
    });

    it('should return the full list if 3 or fewer items', () => {
      const list = "SF6, Tekken 8";
      expect(formatList(list)).toBe("SF6, Tekken 8");
    });

    it('should truncate and add ellipsis if more than 3 items', () => {
      const list = "SF6, Tekken 8, GGST, Melee";
      expect(formatList(list)).toBe("SF6, Tekken 8, GGST...");
    });
  });
});