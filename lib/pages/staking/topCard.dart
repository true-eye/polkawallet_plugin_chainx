import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_chainx/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_plugin_chainx/store/staking/types/nominationData.dart';
import 'package:polkawallet_plugin_chainx/store/staking/types/validatorData.dart';

class TopCard extends StatelessWidget {
  TopCard(this.validatorsInfo, this.validNominations, this.nominationLoading, this.currentAccount) : hasData = validatorsInfo != null && nominationLoading;

  final bool nominationLoading;
  final List<ValidatorData> validatorsInfo;
  final List<NominationData> validNominations;
  final String currentAccount;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final dicStaking = I18n.of(context).getDic(i18n_full_dic_chainx, 'staking');

    final validatorCount = validatorsInfo.where((i) => i.isValidating).length;

    List<Widget> res = [];
    BigInt total = BigInt.zero;

    res.add(Padding(padding: EdgeInsets.only(left: 20, bottom: 10), child: Text(dicStaking['mystaking.label'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))));

    if (currentAccount.isNotEmpty) {
      validNominations.forEach((nmn) {
        BigInt chunks = BigInt.zero;
        nmn.unbondedChunks?.forEach((chunk) => {chunks += BigInt.parse(chunk.value)});

        if (nmn.account == currentAccount) {
          total += BigInt.parse(nmn.nomination);
        }
      });
    }

    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: EdgeInsets.all(16),
      child: !hasData
          ? Container(
              padding: EdgeInsets.only(top: 80, bottom: 80),
              child: CupertinoActivityIndicator(),
            )
          : Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            dicStaking['top.elector'],
                            style: Theme.of(context).textTheme.headline4,
                          ),
                          Text('$validatorCount / ${validatorsInfo.length}')
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            total.toString(),
                            style: Theme.of(context).textTheme.headline4,
                          ),
                          Text(
                            dicStaking['top.myvotes'],
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
    );
  }
}