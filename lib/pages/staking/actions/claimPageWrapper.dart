import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_chainx/pages/staking/actions/claimPage.dart';
import 'package:polkawallet_plugin_chainx/polkawallet_plugin_chainx.dart';
import 'package:polkawallet_plugin_chainx/store/staking/types/validatorData.dart';
import 'package:polkawallet_plugin_chainx/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class ClaimPageWrapper extends StatefulWidget {
  ClaimPageWrapper(this.plugin, this.keyring);
  static final String route = '/staking/claim';
  final PluginChainX plugin;
  final Keyring keyring;
  @override
  _ClaimPageWrapperState createState() => _ClaimPageWrapperState();
}

class _ClaimPageWrapperState extends State<ClaimPageWrapper> {
  Future<void> _onClaim(TxConfirmParams _bondParams) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_chainx, 'staking');
    final txBond = 'api.tx.xStaking.claim(...${jsonEncode(_bondParams.params)})';
    final res = await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          txTitle: dic['mystaking.action.claim'],
          module: 'utility',
          call: 'batchAll',
          txDisplay: {
            "actions": [
              {'call': '${_bondParams.module}.${_bondParams.call}', ..._bondParams.txDisplay},
            ],
          },
          params: [],
          rawParams: '[[$txBond]]',
        ));
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_chainx, 'staking');
    final ValidatorData detail = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['mystaking.action.claim']),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
            child: ClaimPage(
          widget.plugin,
          widget.keyring,
          detail.accountId,
          onNext: (TxConfirmParams params) => _onClaim(params),
        ));
      }),
    );
  }
}
