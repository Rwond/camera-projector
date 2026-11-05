import { IsDateString } from 'class-validator';

export class ScheduleContentDto {
  @IsDateString()
  publishAt!: string;
}
