import { IsIn, IsOptional, IsString } from 'class-validator';

const PROJECTION_MODES = ['MODE_A_USB_C', 'MODE_B_WIRELESS', 'MODE_C_LENS', 'CAMERA_SHARE', 'SCREEN_SHARE'] as const;

export class QueryCompatibilityDto {
  @IsOptional()
  @IsString()
  deviceModel?: string;

  @IsOptional()
  @IsString()
  accessoryModel?: string;

  @IsOptional()
  @IsIn(PROJECTION_MODES)
  mode?: (typeof PROJECTION_MODES)[number];
}
