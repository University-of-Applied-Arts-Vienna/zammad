import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './currentAdminMessages.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCurrentAdminMessagesQuery(defaults: Mocks.MockDefaultsValue<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CurrentAdminMessagesDocument, defaults)
}

export function waitForCurrentAdminMessagesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CurrentAdminMessagesQuery>(Operations.CurrentAdminMessagesDocument)
}

export function mockCurrentAdminMessagesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CurrentAdminMessagesDocument, message, extensions);
}
