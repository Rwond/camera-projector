import { Controller, Get, Query } from '@nestjs/common';
import { CompatibilityService } from './compatibility.service.js';
import { QueryCompatibilityDto } from './dto/query-compatibility.dto.js';

/**
 * Lecture publique — pas de garde d'authentification : cette matrice alimente la page
 * "Compatibilité" du site public (§9.2 du cahier des charges).
 */
@Controller('compatibility')
export class CompatibilityController {
  constructor(private readonly compatibilityService: CompatibilityService) {}

  @Get()
  query(@Query() dto: QueryCompatibilityDto) {
    return this.compatibilityService.query(dto);
  }
}
