import { Injectable, Logger } from '@nestjs/common';
import type { Notification } from '../generated/prisma/client.js';

export interface NotificationTransport {
  /** Doit renvoyer true en cas de succès, false en cas d'échec (jamais lever). */
  dispatch(notification: Notification): Promise<boolean>;
}

/**
 * Transport par défaut — se contente de journaliser. Aucun fournisseur e-mail/push (SMTP,
 * SendGrid, FCM...) n'est encore intégré : voir STATUS.md. À remplacer par un vrai transport une
 * fois un prestataire choisi, sans changer NotificationsService (dépend de l'interface, pas de
 * cette implémentation).
 */
@Injectable()
export class LogNotificationTransport implements NotificationTransport {
  private readonly logger = new Logger(LogNotificationTransport.name);

  async dispatch(notification: Notification): Promise<boolean> {
    this.logger.log(
      `[stub] notification ${notification.channel} "${notification.template}" pour l'utilisateur ${notification.userId}`,
    );
    return true;
  }
}
