<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import type { NavigationMenuEntry } from '#desktop/components/NavigationMenu/types.ts'
import { useTicketOverviews } from '#desktop/pages/ticket-overviews/composables/useTicketOverviews.ts'
import type {
  OverviewTreeFolderNode,
  OverviewTreeNode,
} from '#desktop/pages/ticket-overviews/composables/useTicketOverviewTree.ts'

interface Props {
  nodes: OverviewTreeNode[]
}

const props = defineProps<Props>()

const { overviewsTicketCountById } = useTicketOverviews()

const folderNodes = computed(() =>
  props.nodes.filter((node): node is OverviewTreeFolderNode => node.type === 'folder'),
)

const overviewItems = computed((): NavigationMenuEntry[] =>
  props.nodes
    .filter((node) => node.type === 'overview')
    .map((node) => ({
      label: node.overview.name,
      id: node.overview.id,
      route: node.overview.link,
      count: overviewsTicketCountById.value[node.overview.id],
    })),
)
</script>

<template>
  <div class="flex flex-col gap-1">
    <CommonSectionCollapse
      v-for="folder in folderNodes"
      :id="`overview-folder-${folder.id}`"
      :key="folder.key"
      :title="folder.name"
    >
      <div class="flex flex-col gap-1 ltr:pl-2 rtl:pr-2">
        <TicketOverviewsFolderTree :nodes="folder.children" />
      </div>
    </CommonSectionCollapse>

    <NavigationMenuList
      v-if="overviewItems.length"
      :aria-label="$t('Overview navigation list')"
      count-variant="info"
      count-size="xs"
      :items="overviewItems"
    />
  </div>
</template>
