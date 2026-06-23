import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AdminMessageUpdatesDocument = gql`
    subscription adminMessageUpdates {
  adminMessageUpdates {
    updatedAt
  }
}
    `;
export function useAdminMessageUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.AdminMessageUpdatesSubscription, Types.AdminMessageUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.AdminMessageUpdatesSubscription, Types.AdminMessageUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.AdminMessageUpdatesSubscription, Types.AdminMessageUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.AdminMessageUpdatesSubscription, Types.AdminMessageUpdatesSubscriptionVariables>(AdminMessageUpdatesDocument, {}, options);
}
export type AdminMessageUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.AdminMessageUpdatesSubscription, Types.AdminMessageUpdatesSubscriptionVariables>;