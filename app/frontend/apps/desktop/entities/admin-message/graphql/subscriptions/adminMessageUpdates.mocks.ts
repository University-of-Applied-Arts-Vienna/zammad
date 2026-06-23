import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './adminMessageUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getAdminMessageUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.AdminMessageUpdatesSubscription>(Operations.AdminMessageUpdatesDocument)
}
