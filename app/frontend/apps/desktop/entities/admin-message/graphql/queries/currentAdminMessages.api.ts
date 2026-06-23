import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CurrentAdminMessagesDocument = gql`
    query currentAdminMessages {
  currentAdminMessages {
    id
    message
    endAt
  }
}
    `;
export function useCurrentAdminMessagesQuery(options: VueApolloComposable.UseQueryOptions<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>(CurrentAdminMessagesDocument, {}, options);
}
export function useCurrentAdminMessagesLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>(CurrentAdminMessagesDocument, {}, options);
}
export type CurrentAdminMessagesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CurrentAdminMessagesQuery, Types.CurrentAdminMessagesQueryVariables>;