export const formatDate = (unixTimestamp: string): string => {
  const dateObj = new Date(parseInt(unixTimestamp) * 1000);
  return dateObj.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  });
};

export const formatList = (items: string | undefined): string => {
  if (!items) return '';
  const list = items.split(', ');
  return list.slice(0, 3).join(', ') + (list.length > 3 ? '...' : '');
};