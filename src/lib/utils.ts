export const formatBounty = (num: number) => {
  if (num <= 0) return "???";
  return new Intl.NumberFormat("vi-VN").format(num) + " ฿";
};

export const getShortName = (fullName: string) => {
  if (!fullName) return "";
  const parts = fullName.trim().split(/\s+/);
  return parts[parts.length - 1];
};
