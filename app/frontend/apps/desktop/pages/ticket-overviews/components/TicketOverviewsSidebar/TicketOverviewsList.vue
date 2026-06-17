<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketOverviews } from '#desktop/pages/ticket-overviews/composables/useTicketOverviews.ts'
import { useTicketOverviewTree } from '#desktop/pages/ticket-overviews/composables/useTicketOverviewTree.ts'

import TicketOverviewsFolderTree from './TicketOverviewsFolderTree.vue'

const { overviews, folders } = useTicketOverviews()

const { tree } = useTicketOverviewTree(overviews, folders)
</script>

<template>
  <TicketOverviewsFolderTree :nodes="tree" />
</template>
