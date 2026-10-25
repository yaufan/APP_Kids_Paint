/// Text shown to parents (Traditional Chinese). Children's screens use icons
/// and voice only; these strings are their accessibility labels.
abstract final class Strings {
  static const appName = 'Kids Paint';

  // Children's buttons (screen-reader labels).
  static const takePhoto = '拍照畫畫';
  static const gallery = '我的作品';
  static const map = '地圖日誌';
  static const camera = '用相機拍';
  static const album = '從相簿選';
  static const home = '回家';
  static const undo = '復原';
  static const bucket = '油漆桶';
  static const crayon = '魔法蠟筆';
  static const favorite = '我的最愛';
  static const realistic = '真實風格';
  static const cute = '可愛風格';

  // Parent gate.
  static const parentGateTitle = '家長確認';
  static const parentGateHint = '請輸入答案';
  static const confirm = '確定';
  static const cancel = '取消';
  static const wrongAnswer = '答案不對，請再試一次';

  // Parent mode.
  static const parentMode = '家長模式';
  static const children = '小朋友';
  static const addChild = '新增小朋友';
  static const dailyLimit = '每日使用時間';
  static String minutes(int m) => '$m 分鐘';
  static const deleteAll = '刪除所有資料';
  static const deleteAllConfirm = '所有作品和小朋友資料都會刪除，而且無法復原。確定要刪除嗎？';
  static const delete = '刪除';
  static const deleted = '已刪除所有資料';
  static const privacy = '隱私說明';
  static const privacyBody = '所有照片和作品都只存在這支手機裡，不會上傳。'
      '這個 APP 不使用定位，地點由小朋友自己選。';
  static const licenses = '開放原始碼授權';
  static const mapComingSoon = '地圖日誌即將推出：作品會記錄在哪裡畫的，之後可以在可愛的城市地圖上看到。';
  static const convertFailed = '這張照片轉不出來，換一張試試看';
}
