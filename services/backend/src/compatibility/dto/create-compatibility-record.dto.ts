import { IsDateString, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

const PROJECTION_MODES = ['MODE_A_USB_C', 'MODE_B_WIRELESS', 'MODE_C_LENS', 'CAMERA_SHARE', 'SCREEN_SHARE'] as const;
const RESULTS = ['UNTESTED', 'IN_TEST', 'VALIDATED', 'PARTIAL', 'NOT_COMPATIBLE', 'RETIRED'] as const;

export class CreateCompatibilityRecordDto {
  @IsString()
  @MinLength(1)
  deviceModel!: string;

  @IsOptional()
  @IsString()
  accessoryModel?: string;

  @IsString()
  @MinLength(1)
  osName!: string;

  @IsOptional()
  @IsString()
  osVersion?: string;

  @IsIn(PROJECTION_MODES)
  mode!: (typeof PROJECTION_MODES)[number];

  @IsString()
  @MinLength(1)
  feature!: string;

  @IsOptional()
  @IsIn(RESULTS)
  result?: (typeof RESULTS)[number];

  @IsOptional()
  @IsString()
  testedVersion?: string;

  @IsOptional()
  @IsDateString()
  testedAt?: string;
}
