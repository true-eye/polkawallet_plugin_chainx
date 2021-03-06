import 'package:polkawallet_plugin_chainx/polkawallet_plugin_chainx.dart';
import 'package:polkawallet_plugin_chainx/store/index.dart';
import 'package:polkawallet_plugin_chainx/utils/format.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ApiStaking {
  ApiStaking(this.plugin, this.keyring)
      : api = plugin.sdk.api,
        store = plugin.store;

  final PluginChainX plugin;
  final Keyring keyring;
  final PolkawalletApi api;
  final PluginStore store;

  Future<List> fetchAccountRewardsEraOptions() async {
    final List res = await api.staking.getAccountRewardsEraOptions();
    return res;
  }

  // this query takes extremely long time
  Future<Map> fetchAccountRewards(int eras) async {
    if (store.staking.ownStashInfo != null && store.staking.ownStashInfo.stakingLedger != null) {
      int bonded = store.staking.ownStashInfo.stakingLedger['active'];
      List unlocking = store.staking.ownStashInfo.stakingLedger['unlocking'];
      if (bonded > 0 || unlocking.length > 0) {
        String address = store.staking.ownStashInfo.stashId;
        print('fetching staking rewards...');
        Map res = await api.staking.queryAccountRewards(address, eras);
        return res;
      }
    }
    return {};
  }

  Future<Map> updateStakingTxs(int page) async {
    store.staking.setTxsLoading(true);

    final res = await Future.wait([
      api.subScan.fetchTxsAsync(
        'staking',
        page: page,
        sender: keyring.current.address,
        network: plugin.basic.name,
      ),
      api.subScan.fetchTxsAsync(
        'utility',
        call: 'batchAll',
        page: page,
        sender: keyring.current.address,
        network: plugin.basic.name,
      ),
    ]);
    final list = res[0];
    if (res[1] != null && res[1]['extrinsics'] != null) {
      final batchTxs = List.of(res[1]['extrinsics']);
      batchTxs.retainWhere((e) => (e['params'] as String).contains('Staking'));
      final allTxs = [...res[0]['extrinsics'], ...batchTxs];
      allTxs.sort((a, b) => a['block_num'] < b['block_num'] ? 1 : -1);
      res[0]['extrinsics'] = allTxs;
    }
    await store.staking.addTxs(
      list,
      keyring.current.pubKey,
      shouldCache: page == 0,
      reset: page == 0,
    );

    store.staking.setTxsLoading(false);

    return list;
  }

  Future<Map> updateStakingRewards() async {
    final res = await api.subScan.fetchRewardTxsAsync(
      page: 0,
      sender: keyring.current.address,
      network: plugin.basic.name,
    );

    await store.staking.addTxsRewards(res, keyring.current.pubKey, shouldCache: true);
    return res;
  }

  // this query takes a long time
  Future<void> queryElectedInfo() async {
    // fetch all validators details
    final res = await api.staking.queryElectedInfo();
    store.staking.setValidatorsInfo(res);

    queryNominations(keyring.current.address);

    List validatorAddressList = res['validatorIds'];
    plugin.service.gov.updateIconsAndIndices(validatorAddressList);
  }

  Future<void> queryNominations(String accountId) async {
    // fetch nominators for all validators
    // tricky part here: just using exposure field for getting nominations and dividend of accounts. Other fields are empty

    store.staking.setNominationLoading(true);
    final res = await api.staking.queryOwnStashInfo(accountId);
    store.staking.setNominations(res.exposure, accountId);
    store.staking.setNominationLoading(false);
  }

  Future<Map> queryValidatorRewards(String accountId) async {
    int timestamp = DateTime.now().second;
    Map cached = store.staking.rewardsChartDataCache[accountId];
    if (cached != null && cached['timestamp'] > timestamp - 1800) {
      return cached;
    }
    print('fetching rewards chart data');
    Map data = await api.staking.loadValidatorRewardsData(accountId);
    if (data != null) {
      // format rewards data & set cache
      Map chartData = PluginFmt.formatRewardsChartData(data);
      chartData['timestamp'] = timestamp;
      store.staking.setRewardsChartData(accountId, chartData);
    }
    return data;
  }

  Future<void> queryAccountBondedInfo() async {
    // final data = await api.staking.queryBonded(keyring.allAccounts.map((e) => e.pubKey).toList());
    // store.staking.setAccountBondedMap(data);
  }
}
