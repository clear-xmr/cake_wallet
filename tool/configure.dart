import 'dart:convert';
import 'dart:io';

const bitcoinOutputPath = 'lib/bitcoin/bitcoin.dart';
const moneroOutputPath = 'lib/monero/monero.dart';
const walletTypesPath = 'lib/wallet_types.g.dart';
const pubspecDefaultPath = 'pubspec_default.yaml';
const pubspecOutputPath = 'pubspec.yaml';

Future<void> main(List<String> args) async {
  const prefix = '--';
  final hasBitcoin = args.contains('${prefix}bitcoin');
  final hasMonero = args.contains('${prefix}monero');
  await generateBitcoin(hasBitcoin);
  await generateMonero(hasMonero);
  await generatePubspec(hasMonero: hasMonero, hasBitcoin: hasBitcoin);
  await generateWalletTypes(hasMonero: hasMonero, hasBitcoin: hasBitcoin);
}

Future<void> generateBitcoin(bool hasImplementation) async {
  final outputFile = File(bitcoinOutputPath);
  const bitcoinCommonHeaders = """
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:hive/hive.dart';""";
  const bitcoinCWHeaders = """
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/bitcoin_wallet_service.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/litecoin_wallet_service.dart';
""";
  const bitcoinCwPart = "part 'cw_bitcoin.dart';";
  const bitcoinContent = """
class Unspent {
  Unspent(this.address, this.hash, this.value, this.vout)
      : isSending = true,
        isFrozen = false,
        note = '';

  final String address;
  final String hash;
  final int value;
  final int vout;
  
  bool isSending;
  bool isFrozen;
  String note;

  bool get isP2wpkh => address.startsWith('bc') || address.startsWith('ltc');
}

abstract class Bitcoin {
  TransactionPriority getMediumTransactionPriority();

  WalletCredentials createBitcoinRestoreWalletFromSeedCredentials({String name, String mnemonic, String password});
  WalletCredentials createBitcoinRestoreWalletFromWIFCredentials({String name, String password, String wif, WalletInfo walletInfo});
  WalletCredentials createBitcoinNewWalletCredentials({String name, WalletInfo walletInfo});
  List<String> getWordList();
  Map<String, String> getWalletKeys(Object wallet);
  List<TransactionPriority> getTransactionPriorities();
  List<TransactionPriority> getLitecoinTransactionPriorities();
  TransactionPriority deserializeBitcoinTransactionPriority(int raw); 
  int getFeeRate(Object wallet, TransactionPriority priority);
  Future<void> generateNewAddress(Object wallet);
  Object createBitcoinTransactionCredentials(List<Output> outputs, TransactionPriority priority);

  List<String> getAddresses(Object wallet);
  String getAddress(Object wallet);

  String formatterBitcoinAmountToString({int amount});
  double formatterBitcoinAmountToDouble({int amount});
  int formatterStringDoubleToBitcoinAmount(String amount);

  List<Unspent> getUnspents(Object wallet);
  void updateUnspents(Object wallet);
  WalletService createBitcoinWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  WalletService createLitecoinWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
}
  """;

  const bitcoinEmptyDefinition = 'Bitcoin bitcoin;\n';
  const bitcoinCWDefinition = 'Bitcoin bitcoin = CWBitcoin();\n';

  final output = '$bitcoinCommonHeaders\n'
    + (hasImplementation ? '$bitcoinCWHeaders\n' : '\n')
    + (hasImplementation ? '$bitcoinCwPart\n\n' : '\n')
    + (hasImplementation ? bitcoinCWDefinition : bitcoinEmptyDefinition)
    + '\n'
    + bitcoinContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateMonero(bool hasImplementation) async {
  final outputFile = File(moneroOutputPath);
  const moneroCommonHeaders = """
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/output_info.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';""";
  const moneroCWHeaders = """
import 'package:cw_monero/get_height_by_date.dart';
import 'package:cw_monero/monero_amount_format.dart';
import 'package:cw_monero/monero_transaction_priority.dart';
import 'package:cw_monero/monero_wallet_service.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:cw_monero/monero_transaction_info.dart';
import 'package:cw_monero/monero_transaction_history.dart';
import 'package:cw_monero/monero_transaction_creation_credentials.dart';
import 'package:cw_monero/account.dart' as monero_account;
import 'package:cw_monero/api/wallet.dart' as monero_wallet_api;
import 'package:cw_monero/mnemonics/english.dart';
import 'package:cw_monero/mnemonics/chinese_simplified.dart';
import 'package:cw_monero/mnemonics/dutch.dart';
import 'package:cw_monero/mnemonics/german.dart';
import 'package:cw_monero/mnemonics/japanese.dart';
import 'package:cw_monero/mnemonics/russian.dart';
import 'package:cw_monero/mnemonics/spanish.dart';
import 'package:cw_monero/mnemonics/portuguese.dart';
import 'package:cw_monero/mnemonics/french.dart';
import 'package:cw_monero/mnemonics/italian.dart';
""";
  const moneroCwPart = "part 'cw_monero.dart';";
  const moneroContent = """
class Account {
  Account({this.id, this.label});
  final int id;
  final String label;
}

class Subaddress {
  Subaddress({this.id, this.accountId, this.label, this.address});
  final int id;
  final int accountId;
  final String label;
  final String address;
}

class MoneroBalance extends Balance {
  MoneroBalance({@required this.fullBalance, @required this.unlockedBalance})
      : formattedFullBalance = monero.formatterMoneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            monero.formatterMoneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  MoneroBalance.fromString(
      {@required this.formattedFullBalance,
      @required this.formattedUnlockedBalance})
      : fullBalance = monero.formatterMoneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = monero.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
        super(monero.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
            monero.formatterMoneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

abstract class MoneroWalletDetails {
  @observable
  Account account;

  @observable
  MoneroBalance balance;
}

abstract class Monero {
  MoneroAccountList getAccountList(Object wallet);
  
  MoneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  MoneroWalletDetails getMoneroWalletDetails(Object wallet);

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  int getHeigthByDate({DateTime date});
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority deserializeMoneroTransactionPriority({int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getMoneroWordList(String language);

  WalletCredentials createMoneroRestoreWalletFromKeysCredentials({
      String name,
            String spendKey,
            String viewKey,
            String address,
            String password,
            String language,
            int height});
  WalletCredentials createMoneroRestoreWalletFromSeedCredentials({String name, String password, int height, String mnemonic});
  WalletCredentials createMoneroNewWalletCredentials({String name, String password, String language});
  Map<String, String> getKeys(Object wallet);
  Object createMoneroTransactionCreationCredentials({List<Output> outputs, TransactionPriority priority});
  String formatterMoneroAmountToString({int amount});
  double formatterMoneroAmountToDouble({int amount});
  int formatterMoneroParseAmount({String amount});
  Account getCurrentAccount(Object wallet);
  void setCurrentAccount(Object wallet, Account account);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createMoneroWalletService(Box<WalletInfo> walletInfoSource);
}

abstract class MoneroSubaddressList {
  ObservableList<Subaddress> get subaddresses;
  void update(Object wallet, {int accountIndex});
  void refresh(Object wallet, {int accountIndex});
  List<Subaddress> getAll(Object wallet);
  Future<void> addSubaddress(Object wallet, {int accountIndex, String label});
  Future<void> setLabelSubaddress(Object wallet,
      {int accountIndex, int addressIndex, String label});
}

abstract class MoneroAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {String label});
  Future<void> setLabelAccount(Object wallet, {int accountIndex, String label});
}
  """;

  const moneroEmptyDefinition = 'Monero monero;\n';
  const moneroCWDefinition = 'Monero monero = CWMonero();\n';

  final output = '$moneroCommonHeaders\n'
    + (hasImplementation ? '$moneroCWHeaders\n' : '\n')
    + (hasImplementation ? '$moneroCwPart\n\n' : '\n')
    + (hasImplementation ? moneroCWDefinition : moneroEmptyDefinition)
    + '\n'
    + moneroContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generatePubspec({bool hasMonero, bool hasBitcoin}) async {
  const cwCore =  """
  cw_core:
    path: ./cw_core
    """;
  const cwMonero = """
  cw_monero:
    path: ./cw_monero
  """;
  const cwBitcoin = """
  cw_bitcoin:
    path: ./cw_bitcoin
  """;
  final inputFile = File(pubspecOutputPath);
  final inputText = await inputFile.readAsString();
  final inputLines = inputText.split('\n');
  final dependenciesIndex = inputLines.indexWhere((line) => line.toLowerCase() == 'dependencies:');
  var output = cwCore;

  if (hasMonero) {
    output += '\n$cwMonero';
  }

  if (hasBitcoin) {
    output += '\n$cwBitcoin';
  }

  final outputLines = output.split('\n');
  inputLines.insertAll(dependenciesIndex + 1, outputLines);
  final outputContent = inputLines.join('\n');
  final outputFile = File(pubspecOutputPath);
  
  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(outputContent);
}

Future<void> generateWalletTypes({bool hasMonero, bool hasBitcoin}) async {
  final walletTypesFile = File(walletTypesPath);
  
  if (walletTypesFile.existsSync()) {
    await walletTypesFile.delete();
  }

  const outputHeader = "import 'package:cw_core/wallet_type.dart';";
  const outputDefinition = 'final availableWalletTypes = <WalletType>[';
  var outputContent = outputHeader + '\n\n' + outputDefinition + '\n';

  if (hasMonero) {
    outputContent += '\tWalletType.monero,\n';
  }

  if (hasBitcoin) {
    outputContent += '\tWalletType.bitcoin,\n\tWalletType.litecoin,\n';
  }

  outputContent += '];\n';
  await walletTypesFile.writeAsString(outputContent);
}