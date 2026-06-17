// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef, type Ref } from 'vue'

import type { OverviewFoldersQuery, OverviewAttributesFragment } from '#shared/graphql/types.ts'

export type OverviewItem = OverviewAttributesFragment
export type OverviewFolderItem = OverviewFoldersQuery['userCurrentTicketOverviewFolders'][number]

export interface OverviewTreeOverviewNode {
  type: 'overview'
  key: string
  overview: OverviewItem
}

export interface OverviewTreeFolderNode {
  type: 'folder'
  key: string
  id: number
  name: string
  children: OverviewTreeNode[]
}

export type OverviewTreeNode = OverviewTreeFolderNode | OverviewTreeOverviewNode

/**
 * Builds the folder/overview tree shown in the agent overview sidebar.
 *
 * - Folders are ordered by their admin-defined `prio`.
 * - Overviews keep the order of the (already sorted) `overviews` input, both at
 *   root level and within a folder.
 * - Overviews whose folder is not visible (e.g. inactive or pruned) and folders
 *   whose parent is not visible fall back to the root level.
 */
export const useTicketOverviewTree = (
  overviews: Ref<OverviewItem[]> | ComputedRef<OverviewItem[]>,
  folders: Ref<OverviewFolderItem[]> | ComputedRef<OverviewFolderItem[]>,
): { tree: ComputedRef<OverviewTreeNode[]> } => {
  const tree = computed<OverviewTreeNode[]>(() => {
    const folderList = folders.value ?? []
    const overviewList = overviews.value ?? []

    const visibleFolderIds = new Set(folderList.map((folder) => folder.internalId))

    const sortedFolders = [...folderList].sort((a, b) => a.prio - b.prio)

    const foldersByParent = new Map<number | null, OverviewFolderItem[]>()
    sortedFolders.forEach((folder) => {
      // Treat a folder with a missing/invisible parent as a root folder.
      const parentId =
        folder.parentId && visibleFolderIds.has(folder.parentId) ? folder.parentId : null

      const siblings = foldersByParent.get(parentId) ?? []
      siblings.push(folder)
      foldersByParent.set(parentId, siblings)
    })

    const overviewsByFolder = new Map<number | null, OverviewItem[]>()
    overviewList.forEach((overview) => {
      const folderId =
        overview.folderId && visibleFolderIds.has(overview.folderId) ? overview.folderId : null

      const items = overviewsByFolder.get(folderId) ?? []
      items.push(overview)
      overviewsByFolder.set(folderId, items)
    })

    const buildNodes = (parentId: number | null): OverviewTreeNode[] => {
      const folderNodes: OverviewTreeNode[] = (foldersByParent.get(parentId) ?? []).map(
        (folder) => ({
          type: 'folder',
          key: `folder-${folder.internalId}`,
          id: folder.internalId,
          name: folder.name,
          children: buildNodes(folder.internalId),
        }),
      )

      const overviewNodes: OverviewTreeNode[] = (overviewsByFolder.get(parentId) ?? []).map(
        (overview) => ({
          type: 'overview',
          key: `overview-${overview.id}`,
          overview,
        }),
      )

      // Folders are shown first, then the overviews sitting directly at this level.
      return [...folderNodes, ...overviewNodes]
    }

    return buildNodes(null)
  })

  return { tree }
}
