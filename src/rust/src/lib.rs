// このライブラリは公式Nuked-OPM (https://github.com/nukeykt/Nuked-OPM) を
// Windows向けにビルドしたものです。
//
// 提供される関数は公式のopm.hと同じシグネチャです：
// - void OPM_Reset(opm_t *chip);
// - void OPM_Write(opm_t *chip, uint32_t port, uint8_t data);
// - void OPM_Clock(opm_t *chip, int32_t *output, uint8_t *sh1, uint8_t *sh2, uint8_t *so);
// - uint8_t OPM_Read(opm_t *chip, uint32_t port);
// - uint8_t OPM_ReadIRQ(opm_t *chip);
// - uint8_t OPM_ReadCT1(opm_t *chip);
// - uint8_t OPM_ReadCT2(opm_t *chip);
// - void OPM_SetIC(opm_t *chip, uint8_t ic);
//
// 詳細は公式リポジトリのopm.hを参照してください。
//
// このlib.rsファイルは、静的ライブラリ(.a)をビルドするためだけに存在します。
// 実際の関数定義はbuild.rsでコンパイルされるopm.cから提供されます。

// Note: Rustからこのライブラリを使う場合は、上記の公式シグネチャで
// extern "C" 宣言を行ってください。ラッパーは不要です。
