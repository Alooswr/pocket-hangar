// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '口袋机库';

  @override
  String get tabSkills => '技能';

  @override
  String get tabMarket => '市场';

  @override
  String get tabAssets => '船只';

  @override
  String get tabFitting => '装配';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get copy => '复制';

  @override
  String get search => '搜索';

  @override
  String get loading => '正在加载…';

  @override
  String errorWithMessage(Object message) {
    return '出错了：$message';
  }

  @override
  String get errorNetwork => '网络请求失败，检查网络后重试。';

  @override
  String errorEsiThrottled(Object seconds) {
    return 'ESI 正在限流，$seconds 秒后再试。';
  }

  @override
  String errorEsiServer(Object status) {
    return 'ESI 返回 $status，稍后再试。';
  }

  @override
  String get errorForbidden => '这个角色没有授权访问这项数据。';

  @override
  String errorReloginNeeded(Object name) {
    return '$name 的授权已失效，请重新登录。';
  }

  @override
  String updatedAt(Object time) {
    return '$time 更新';
  }

  @override
  String get characters => '角色';

  @override
  String get addCharacter => '添加角色';

  @override
  String get signInAgain => '重新登录';

  @override
  String get switchCharacter => '切换角色';

  @override
  String removeCharacter(Object name) {
    return '移除 $name';
  }

  @override
  String removeCharacterConfirm(Object name) {
    return '从本机移除 $name？之后可以重新添加。';
  }

  @override
  String get removeCharacterAction => '移除角色';

  @override
  String get noCharacterTitle => '还没有角色';

  @override
  String get noCharacterBody => '用 EVE Online 账号登录后可以查看技能、船只和挂单。装配和市场不登录也能用。';

  @override
  String get clientIdMissing =>
      '这个版本没有配置 EVE 应用的 Client ID，构建时用 --dart-define=EVE_CLIENT_ID=<你的 Client ID> 传入。';

  @override
  String get loginCancelled => '已取消登录。';

  @override
  String loginFailed(Object message) {
    return '登录失败：$message';
  }

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get dataSection => '游戏数据';

  @override
  String dataBuild(Object build, Object date) {
    return '版本 $build，$date 发布';
  }

  @override
  String get dataNone => '尚未下载';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get aboutSection => '关于';

  @override
  String appVersion(Object version) {
    return '版本 $version';
  }

  @override
  String get sourceCode => '源代码（MIT 协议）';

  @override
  String get ccpNotice =>
      'EVE Online 的数据、图片和商标归 CCP hf. 所有，本应用按 CCP 开发者许可协议使用。© 2014 CCP hf. All rights reserved. \"EVE\", \"EVE Online\", \"CCP\", and all related logos and images are trademarks or registered trademarks of CCP hf.';

  @override
  String get sdeOnboardingTitle => '下载游戏数据';

  @override
  String sdeOnboardingBody(Object size) {
    return '物品、技能和星图数据，约 $size。只需下载一次，之后装配可以离线使用。';
  }

  @override
  String sdeDownload(Object size) {
    return '下载 $size';
  }

  @override
  String sdeDownloading(Object percent) {
    return '正在下载 $percent%';
  }

  @override
  String get sdeInstalling => '正在校验并安装…';

  @override
  String sdeUpdateAvailable(Object build, Object size) {
    return '游戏数据有新版本 $build（$size）。';
  }

  @override
  String get sdeUpdate => '更新数据';

  @override
  String get sdeUpToDate => '游戏数据已是最新。';

  @override
  String get sdeChecksumFailed => '下载校验失败（SHA-256 不一致），本地数据没有改动。';

  @override
  String get sdeSchemaTooNew => '这份游戏数据需要更新版本的 App，请先更新 App。';

  @override
  String sdeInstalled(Object build) {
    return '已安装游戏数据 $build。';
  }

  @override
  String appUpdateAvailable(Object version) {
    return '新版本 $version 已发布。';
  }

  @override
  String get appUpdateDownload => '下载';

  @override
  String get appUpdateOpenStore => '前往 App Store';

  @override
  String get appUpToDate => '已是最新版本。';

  @override
  String get skillsTitle => '技能';

  @override
  String totalSp(Object sp) {
    return '$sp 技能点';
  }

  @override
  String unallocatedSp(Object sp) {
    return '$sp 未分配';
  }

  @override
  String get skillQueue => '训练队列';

  @override
  String get queueEmpty => '训练队列是空的。';

  @override
  String get queuePaused => '队列已暂停';

  @override
  String trainingRate(Object rate) {
    return '每分钟 $rate 技能点';
  }

  @override
  String skillFinishes(Object time) {
    return '$time 完成';
  }

  @override
  String skillLeft(Object duration) {
    return '还剩 $duration';
  }

  @override
  String queueFinishesIn(Object duration) {
    return '整个队列还要 $duration';
  }

  @override
  String queueFinishesAt(Object time) {
    return '最后一个技能 $time 完成';
  }

  @override
  String get alphaClone => '阿尔法克隆：训练速度减半';

  @override
  String rateFromServer(Object percent) {
    return '完成时间取自服务器队列。本地估算与它相差 $percent%（可能用了加速器或重新分配过属性）。';
  }

  @override
  String get attributes => '属性';

  @override
  String get attrIntelligence => '智力';

  @override
  String get attrMemory => '记忆';

  @override
  String get attrPerception => '感知';

  @override
  String get attrWillpower => '毅力';

  @override
  String get attrCharisma => '魅力';

  @override
  String implantBonus(Object bonus) {
    return '植入体 +$bonus';
  }

  @override
  String durationDHM(Object d, Object h, Object m) {
    return '$d 天 $h 小时 $m 分';
  }

  @override
  String durationHM(Object h, Object m) {
    return '$h 小时 $m 分';
  }

  @override
  String durationMS(Object m, Object s) {
    return '$m 分 $s 秒';
  }

  @override
  String get marketTitle => '市场';

  @override
  String get searchItems => '搜索物品';

  @override
  String get favorites => '收藏';

  @override
  String get favoritesEmpty => '收藏的物品会显示在这里。';

  @override
  String get addFavorite => '加入收藏';

  @override
  String get removeFavorite => '取消收藏';

  @override
  String noResults(Object query) {
    return '没有找到“$query”。';
  }

  @override
  String get sellOrders => '卖单';

  @override
  String get buyOrders => '买单';

  @override
  String get history => '历史';

  @override
  String get jitaOnly => '只看吉他 4-4';

  @override
  String get lowestSell => '最低卖价';

  @override
  String get highestBuy => '最高买价';

  @override
  String ordersIn(Object count, Object region) {
    return '$region共 $count 个挂单';
  }

  @override
  String get noOrders => '没有挂单。';

  @override
  String priceHistoryTitle(Object days) {
    return '近 $days 天均价';
  }

  @override
  String priceChange(Object change, Object days) {
    return '$days 天内 $change';
  }

  @override
  String get noHistory => '没有成交记录。';

  @override
  String get columnPrice => '价格';

  @override
  String get columnQuantity => '数量';

  @override
  String get columnLocation => '地点';

  @override
  String get playerStructure => '玩家建筑';

  @override
  String get assetsTitle => '船只';

  @override
  String get currentShip => '当前船只';

  @override
  String get inSpace => '太空中';

  @override
  String get unknownStructure => '未知建筑';

  @override
  String get unknownSystem => '星系未知';

  @override
  String get noShips => '没有找到船只。';

  @override
  String get packaged => '已打包';

  @override
  String shipCount(Object count) {
    return '$count 艘船';
  }

  @override
  String insideContainer(Object name) {
    return '在 $name 里';
  }

  @override
  String get fittingTitle => '装配';

  @override
  String get newFit => '新建配装';

  @override
  String get chooseShip => '选择舰船';

  @override
  String get searchShips => '搜索舰船';

  @override
  String get importEft => '导入 EFT';

  @override
  String get exportEft => '复制为 EFT';

  @override
  String get eftPasteHint => '粘贴 EFT 格式的配装';

  @override
  String get eftImport => '导入';

  @override
  String eftImportFailed(Object reason) {
    return '无法读取这段 EFT 文本：$reason';
  }

  @override
  String eftSkipped(Object names) {
    return '以下物品没有找到，已跳过：$names';
  }

  @override
  String get copied => '已复制到剪贴板。';

  @override
  String get savedFits => '已保存的配装';

  @override
  String get savedFitsEmpty => '保存的配装会显示在这里。';

  @override
  String get deleteFit => '删除配装';

  @override
  String deleteFitConfirm(Object name) {
    return '删除“$name”？删除后无法恢复。';
  }

  @override
  String get fitName => '配装名称';

  @override
  String get slotHigh => '高槽';

  @override
  String get slotMid => '中槽';

  @override
  String get slotLow => '低槽';

  @override
  String get slotRig => '改装件';

  @override
  String get slotSubsystem => '子系统';

  @override
  String get emptySlot => '空槽位';

  @override
  String get addModule => '添加装备';

  @override
  String get chooseModule => '选择装备';

  @override
  String get chooseCharge => '选择弹药';

  @override
  String get removeModule => '卸下装备';

  @override
  String get removeCharge => '卸下弹药';

  @override
  String get moduleState => '状态';

  @override
  String get stateOffline => '离线';

  @override
  String get stateOnline => '在线';

  @override
  String get stateActive => '启用';

  @override
  String get stateOverheated => '超载';

  @override
  String get skillsAllV => '全技能 5 级';

  @override
  String skillsOf(Object name) {
    return '$name 的技能';
  }

  @override
  String get statFitting => '装配资源';

  @override
  String get statCpu => 'CPU';

  @override
  String get statPowergrid => '能量栅格';

  @override
  String get statCalibration => '校准值';

  @override
  String get statTurrets => '炮台';

  @override
  String get statLaunchers => '发射器';

  @override
  String get statCapacitor => '电容';

  @override
  String capStable(Object percent) {
    return '稳定在 $percent%';
  }

  @override
  String capLasts(Object duration) {
    return '$duration 后耗尽';
  }

  @override
  String capRecharge(Object seconds) {
    return '回充 $seconds 秒';
  }

  @override
  String capDelta(Object use, Object peak) {
    return '消耗 $use GJ/s，峰值回充 $peak GJ/s';
  }

  @override
  String get statDefense => '防御';

  @override
  String get layerShield => '护盾';

  @override
  String get layerArmor => '装甲';

  @override
  String get layerHull => '结构';

  @override
  String get damageEm => '电磁';

  @override
  String get damageThermal => '热能';

  @override
  String get damageKinetic => '动能';

  @override
  String get damageExplosive => '爆炸';

  @override
  String get ehp => '有效血量';

  @override
  String get ehpUniform => '均匀伤害下的有效血量';

  @override
  String get statNavigation => '机动';

  @override
  String get maxVelocity => '最大速度';

  @override
  String get alignTime => '起跳时间';

  @override
  String get signatureRadius => '信号半径';

  @override
  String get mass => '质量';

  @override
  String fitTooMuchCpu(Object amount) {
    return 'CPU 超出 $amount tf';
  }

  @override
  String fitTooMuchPower(Object amount) {
    return '能量栅格超出 $amount MW';
  }

  @override
  String fitTooMuchCalibration(Object amount) {
    return '校准值超出 $amount';
  }

  @override
  String fitNoFreeSlot(Object name) {
    return '没有空槽位放 $name';
  }

  @override
  String fitWrongShip(Object name) {
    return '$name 不能装到这艘船上';
  }

  @override
  String get uploadFitToGame => '保存到游戏内配装';

  @override
  String get tabModules => '模块';

  @override
  String get tabStats => '属性';

  @override
  String get drones => '无人机';

  @override
  String get cargo => '货柜舱';

  @override
  String get paste => '粘贴';

  @override
  String get rename => '重命名';

  @override
  String get discard => '放弃';

  @override
  String get unsavedChanges => '放弃对这套配置的修改？';

  @override
  String get fitSaved => '配置已保存。';

  @override
  String fitUploaded(Object name) {
    return '已保存到 $name 的游戏内配装。';
  }

  @override
  String get uploadNeedsCharacter => '先登录一个角色。';

  @override
  String get fitEmptyCannotUpload => '至少装上一个模块再保存到游戏。';

  @override
  String fitGroupLimit(Object count, Object name) {
    return '$name 这类模块最多装 $count 个。';
  }

  @override
  String secondsValue(Object value) {
    return '$value 秒';
  }

  @override
  String skillsLoadFailed(Object name) {
    return '读不到 $name 的技能，先按全技能 5 级计算。';
  }

  @override
  String get shipSearchHint => '输入舰船名，中英文都可以。只打一部分或打错一两个字也能找到。';

  @override
  String get capCapacity => '容量';

  @override
  String get capRechargeTime => '回充时间';

  @override
  String get capStatus => '状态';

  @override
  String get hpColumn => 'HP';

  @override
  String get fillSlots => '装满同类空槽';

  @override
  String get unknownShip => '已安装的游戏数据里没有这艘船。';

  @override
  String get noItems => '这里没有可选的物品。';

  @override
  String get eftErrorEmpty => '内容是空的';

  @override
  String get eftErrorHeader => '第一行要写成 [舰船, 配置名]';

  @override
  String eftErrorShip(Object name) {
    return '找不到叫“$name”的舰船';
  }

  @override
  String get damageEmShort => '电磁';

  @override
  String get damageThermalShort => '热能';

  @override
  String get damageKineticShort => '动能';

  @override
  String get damageExplosiveShort => '爆炸';

  @override
  String errorHttpStatus(Object status) {
    return '服务器返回 $status，稍后再试。';
  }

  @override
  String get sdeNotPublished => '还没有发布游戏数据，稍后再试。';

  @override
  String ordersAtJita(Object count) {
    return '吉他 4-4 共 $count 个挂单';
  }
}
