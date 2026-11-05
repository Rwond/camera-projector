import { IsString, MinLength } from 'class-validator';

export class ClaimAccessoryDto {
  @IsString()
  @MinLength(4)
  serialNumber!: string;
}
