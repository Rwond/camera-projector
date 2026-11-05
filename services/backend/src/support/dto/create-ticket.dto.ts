import { IsIn, IsString, MinLength } from 'class-validator';

const CATEGORIES = ['ACCOUNT', 'PAYMENT', 'CONNECTION', 'QUALITY', 'COMPATIBILITY', 'HARDWARE', 'SECURITY'] as const;

export class CreateTicketDto {
  @IsIn(CATEGORIES)
  category!: (typeof CATEGORIES)[number];

  @IsString()
  @MinLength(1)
  message!: string;
}
