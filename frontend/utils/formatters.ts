export const formatDate = (unixTimestamp: string): string => {
  const dateObj = new Date(parseInt(unixTimestamp) * 1000);
  return dateObj.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  });
};

