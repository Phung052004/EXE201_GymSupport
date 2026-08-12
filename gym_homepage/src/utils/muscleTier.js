const TIERS = {
  Iron: { color: '#6B7280', label: 'Iron' },
  Bronze: { color: '#B87333', label: 'Bronze' },
  Silver: { color: '#9CA3AF', label: 'Silver' },
  Gold: { color: '#D4AF37', label: 'Gold' },
  Platinum: { color: '#5EEAD4', label: 'Platinum' },
  Diamond: { color: '#38BDF8', label: 'Diamond' },
  Champion: { color: '#A855F7', label: 'Champion' },
}

export function getTierMeta(tier) {
  return TIERS[tier] ?? { color: '#9CA3AF', label: tier || 'Chưa xếp hạng' }
}

export const TIER_ORDER = ['Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Champion']
