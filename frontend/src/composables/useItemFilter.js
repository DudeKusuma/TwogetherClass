import { computed, unref } from 'vue'

// Required course file. Kept minimal and intentionally unused in Twogether Class.
export function useItemFilter(items, query) {
  return computed(() => {
    const q = (unref(query) ?? '').toLowerCase().trim()
    const list = unref(items) ?? []
    return q ? list.filter((i) => String(i.name ?? '').toLowerCase().includes(q)) : list
  })
}
