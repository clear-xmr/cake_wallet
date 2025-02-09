import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/mnemonic_length.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'wallet_restore_view_model.g.dart';

enum WalletRestoreMode { seed, keys }

class WalletRestoreViewModel = WalletRestoreViewModelBase
    with _$WalletRestoreViewModel;

abstract class WalletRestoreViewModelBase extends WalletCreationVM with Store {
  WalletRestoreViewModelBase(AppStore appStore, this._walletCreationService,
      Box<WalletInfo> walletInfoSource,
      {@required WalletType type})
      : availableModes = type == WalletType.monero
            ? WalletRestoreMode.values
            : [WalletRestoreMode.seed],
        hasSeedLanguageSelector = type == WalletType.monero,
        hasBlockchainHeightLanguageSelector = type == WalletType.monero,
        super(appStore, walletInfoSource, type: type, isRecovery: true) {
    isButtonEnabled =
        !hasSeedLanguageSelector && !hasBlockchainHeightLanguageSelector;
    mode = WalletRestoreMode.seed;
    _walletCreationService.changeWalletType(type: type);
  }

  static const moneroSeedMnemonicLength = 25;
  static const electrumSeedMnemonicLength = 24;
  static const electrumShortSeedMnemonicLength = 12;

  final List<WalletRestoreMode> availableModes;
  final bool hasSeedLanguageSelector;
  final bool hasBlockchainHeightLanguageSelector;
  final WalletCreationService _walletCreationService;

  @observable
  WalletRestoreMode mode;

  @observable
  bool isButtonEnabled;
  
  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword(type);
    final height = options['height'] as int;
    name = options['name'] as String;

    if (mode == WalletRestoreMode.seed) {
      final seed = options['seed'] as String;

      switch (type) {
        case WalletType.monero:
          return monero.createMoneroRestoreWalletFromSeedCredentials(
              name: name,
              height: height,
              mnemonic: seed,
              password: password);
        case WalletType.bitcoin:
          return bitcoin.createBitcoinRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password);
        case WalletType.litecoin:
          return bitcoin.createBitcoinRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password);
        default:
          break;
      }
    }

    if (mode == WalletRestoreMode.keys) {
      final viewKey = options['viewKey'] as String;
      final spendKey = options['spendKey'] as String;
      final address = options['address'] as String;

      return monero.createMoneroRestoreWalletFromKeysCredentials(
          name: name,
          height: height,
          spendKey: spendKey,
          viewKey: viewKey,
          address: address,
          password: password,
          language: 'English');
    }

    return null;
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    if (mode == WalletRestoreMode.keys) {
      return _walletCreationService.restoreFromKeys(credentials);
    }

    return _walletCreationService.restoreFromSeed(credentials);
  }
}
