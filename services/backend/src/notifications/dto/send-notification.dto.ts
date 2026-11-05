import { IsIn, IsObject, IsOptional, IsString, MinLength } from 'class-validator';

const CHANNELS = ['EMAIL', 'IN_APP', 'PUSH'] as const;

export class SendNotificationDto {
  @IsString()
  @MinLength(1)
  userId!: string;

  @IsIn(CHANNELS)
  channel!: (typeof CHANNELS)[number];

  @IsString()
  @MinLength(1)
  template!: string;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}
