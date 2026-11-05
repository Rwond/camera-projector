import { IsIn, IsOptional, IsString } from 'class-validator';

const DEVICE_TYPES = ['PHONE', 'COMPUTER', 'RECEIVER', 'ACCESSORY_CONTROLLER'] as const;
const DEVICE_PLATFORMS = ['ANDROID', 'IOS', 'WINDOWS', 'MACOS', 'WEB'] as const;

export class RegisterDeviceDto {
  @IsIn(DEVICE_TYPES)
  type!: (typeof DEVICE_TYPES)[number];

  @IsIn(DEVICE_PLATFORMS)
  platform!: (typeof DEVICE_PLATFORMS)[number];

  @IsOptional()
  @IsString()
  model?: string;

  @IsOptional()
  @IsString()
  osVersion?: string;

  @IsOptional()
  @IsString()
  appVersion?: string;
}
