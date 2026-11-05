import { IsIn, IsObject, IsOptional, IsString, MinLength } from 'class-validator';

const CATEGORIES = ['NEWS', 'GUIDE', 'FAQ'] as const;

export class CreateArticleDto {
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
  body!: Record<string, unknown>;

  @IsIn(CATEGORIES)
  category!: (typeof CATEGORIES)[number];
}
