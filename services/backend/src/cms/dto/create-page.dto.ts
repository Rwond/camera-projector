import { IsObject, IsOptional, IsString, MinLength } from 'class-validator';

export class CreatePageDto {
  @IsString()
  @MinLength(1)
  slug!: string;

  @IsOptional()
  @IsString()
  locale?: string;

  @IsString()
  @MinLength(1)
  title!: string;

  @IsObject()
  blocks!: Record<string, unknown>;

  @IsOptional()
  @IsString()
  seoTitle?: string;

  @IsOptional()
  @IsString()
  seoDescription?: string;
}
