import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateCatalogEntryDto {
  @IsString()
  @MinLength(4)
  serialNumber!: string;

  @IsString()
  @MinLength(2)
  model!: string;

  @IsOptional()
  @IsString()
  firmwareVersion?: string;

  @IsOptional()
  @IsString()
  batchNumber?: string;

  @IsOptional()
  @IsDateString()
  warrantyExpiresAt?: string;
}
