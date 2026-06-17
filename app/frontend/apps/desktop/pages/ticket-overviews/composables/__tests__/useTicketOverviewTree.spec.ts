// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import {
  useTicketOverviewTree,
  type OverviewFolderItem,
  type OverviewItem,
  type OverviewTreeFolderNode,
} from '../useTicketOverviewTree.ts'

const overview = (id: string, name: string, folderId: number | null = null): OverviewItem =>
  ({ id, name, link: name.toLowerCase(), folderId }) as unknown as OverviewItem

const folder = (
  internalId: number,
  name: string,
  parentId: number | null = null,
  prio = internalId,
): OverviewFolderItem =>
  ({ id: `gid-${internalId}`, internalId, name, parentId, prio, active: true }) as OverviewFolderItem

describe('useTicketOverviewTree', () => {
  it('keeps overviews without a folder at the root level', () => {
    const { tree } = useTicketOverviewTree(ref([overview('1', 'Root A')]), ref([]))

    expect(tree.value).toEqual([
      expect.objectContaining({ type: 'overview', key: 'overview-1' }),
    ])
  })

  it('groups overviews under their folder and nests subfolders', () => {
    const overviews = ref([
      overview('1', 'Root A'),
      overview('2', 'In Parent', 10),
      overview('3', 'In Child', 11),
    ])
    const folders = ref([folder(10, 'Parent'), folder(11, 'Child', 10)])

    const { tree } = useTicketOverviewTree(overviews, folders)

    // Folder first, then the root overview.
    expect(tree.value).toHaveLength(2)
    const [parentNode, rootOverview] = tree.value
    expect(rootOverview).toMatchObject({ type: 'overview', key: 'overview-1' })

    expect(parentNode.type).toBe('folder')
    const parent = parentNode as OverviewTreeFolderNode
    expect(parent.name).toBe('Parent')

    // Parent contains the child folder (first) then its own overview.
    const childNode = parent.children[0] as OverviewTreeFolderNode
    expect(childNode).toMatchObject({ type: 'folder', name: 'Child' })
    expect(childNode.children).toEqual([
      expect.objectContaining({ type: 'overview', key: 'overview-3' }),
    ])
    expect(parent.children[1]).toMatchObject({ type: 'overview', key: 'overview-2' })
  })

  it('falls back to the root level when the folder is not visible', () => {
    const { tree } = useTicketOverviewTree(
      ref([overview('1', 'Orphan', 999)]),
      ref([]),
    )

    expect(tree.value).toEqual([
      expect.objectContaining({ type: 'overview', key: 'overview-1' }),
    ])
  })

  it('orders folders by their prio', () => {
    const { tree } = useTicketOverviewTree(
      ref([]),
      ref([folder(1, 'Second', null, 20), folder(2, 'First', null, 10)]),
    )

    expect(tree.value.map((node) => (node as OverviewTreeFolderNode).name)).toEqual([
      'First',
      'Second',
    ])
  })
})
