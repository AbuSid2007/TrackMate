"""add trainer_status trainer_id verification_token

Revision ID: a2b10eec9ef7
Revises: 001
Create Date: 2026-03-18 08:13:10.285001

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a2b10eec9ef7'
down_revision: Union[str, None] = '001'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE TYPE trainerstatus AS ENUM ('none', 'pending', 'approved', 'rejected')")
    op.add_column('users', sa.Column('trainer_status', sa.Enum('none', 'pending', 'approved', 'rejected', name='trainerstatus'), nullable=False, server_default='none'))
    op.add_column('users', sa.Column('trainer_id', sa.UUID(), nullable=True))
    op.add_column('users', sa.Column('verification_token', sa.String(length=255), nullable=True))
    op.create_foreign_key(None, 'users', 'users', ['trainer_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    op.drop_constraint(None, 'users', type_='foreignkey')
    op.drop_column('users', 'verification_token')
    op.drop_column('users', 'trainer_id')
    op.drop_column('users', 'trainer_status')
    op.execute("DROP TYPE trainerstatus")