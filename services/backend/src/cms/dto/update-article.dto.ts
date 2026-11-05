import { IsIn, IsObject, IsOptional, IsString, MinLength } from 'class-validator';

const CATEGORIES = ['NEWS', 'GUIDE', 'FAQ'] as const;

export class UpdateArticleDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  title?: string;

  @IsOptional()
  @IsObject()
  body?: Record<string, unknown>;

  @IsOptional()
  @IsIn(CATEGORIES)
  category?: (typeof CATEGORIES)[number];
}
