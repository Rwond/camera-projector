import { IsInt, IsOptional, IsString, IsUrl, Min, MinLength } from 'class-validator';

export class RegisterMediaDto {
  @IsString()
  @MinLength(1)
  filename!: string;

  @IsUrl({ require_tld: false })
  url!: string;

  @IsString()
  @MinLength(1)
  mimeType!: string;

  @IsInt()
  @Min(0)
  sizeBytes!: number;

  @IsOptional()
  @IsString()
  altText?: string;
}
