import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './overviewFolders.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOverviewFoldersQuery(defaults: Mocks.MockDefaultsValue<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.OverviewFoldersDocument, defaults)
}

export function waitForOverviewFoldersQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OverviewFoldersQuery>(Operations.OverviewFoldersDocument)
}

export function mockOverviewFoldersQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OverviewFoldersDocument, message, extensions);
}
