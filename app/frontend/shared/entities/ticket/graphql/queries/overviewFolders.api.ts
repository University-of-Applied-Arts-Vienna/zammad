import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OverviewFoldersDocument = gql`
    query overviewFolders($ignoreUserConditions: Boolean!) {
  userCurrentTicketOverviewFolders(ignoreUserConditions: $ignoreUserConditions) {
    id
    internalId
    name
    prio
    parentId
    active
  }
}
    `;
export function useOverviewFoldersQuery(variables: Types.OverviewFoldersQueryVariables | VueCompositionApi.Ref<Types.OverviewFoldersQueryVariables> | ReactiveFunction<Types.OverviewFoldersQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>(OverviewFoldersDocument, variables, options);
}
export function useOverviewFoldersLazyQuery(variables?: Types.OverviewFoldersQueryVariables | VueCompositionApi.Ref<Types.OverviewFoldersQueryVariables> | ReactiveFunction<Types.OverviewFoldersQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>(OverviewFoldersDocument, variables, options);
}
export type OverviewFoldersQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OverviewFoldersQuery, Types.OverviewFoldersQueryVariables>;
