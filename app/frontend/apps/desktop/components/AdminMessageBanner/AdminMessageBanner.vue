<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'

import { useAdminMessages } from '#desktop/entities/admin-message/composables/useAdminMessages.ts'

const { messages } = useAdminMessages()
</script>

<template>
  <div v-if="messages.length" class="flex shrink-0 flex-col gap-1 p-2">
    <CommonAlert v-for="message in messages" :key="message.id" variant="warning">
      <!-- The message is sanitized server-side (HtmlSanitizer::Strict). -->
      <!-- eslint-disable-next-line vue/no-v-html -->
      <div v-html="message.message" />
    </CommonAlert>
  </div>
</template>
