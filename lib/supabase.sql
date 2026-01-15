-- ============================================
-- TABLAS
-- ============================================

-- Tabla de ocasiones
CREATE TABLE occasions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    occasion_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de categorías de gasto
CREATE TABLE expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    is_predefined BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- Tabla de ingresos (costos en tu terminología)
CREATE TABLE incomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    occasion_id UUID REFERENCES occasions(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de egresos (gastos)
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    occasion_id UUID REFERENCES occasions(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
    amount DECIMAL(12, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de gastos generales (no asociados a ocasiones)
CREATE TABLE general_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
    amount DECIMAL(12, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ÍNDICES
-- ============================================

CREATE INDEX idx_occasions_user_id ON occasions(user_id);
CREATE INDEX idx_occasions_created_at ON occasions(created_at);
CREATE INDEX idx_incomes_occasion_id ON incomes(occasion_id);
CREATE INDEX idx_expenses_occasion_id ON expenses(occasion_id);
CREATE INDEX idx_expense_categories_user_id ON expense_categories(user_id);
CREATE INDEX idx_general_expenses_user_id ON general_expenses(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE occasions ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE incomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE general_expenses ENABLE ROW LEVEL SECURITY;

-- Políticas para occasions
CREATE POLICY "Users can view their own occasions"
    ON occasions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own occasions"
    ON occasions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own occasions"
    ON occasions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own occasions"
    ON occasions FOR DELETE
    USING (auth.uid() = user_id);

-- Políticas para expense_categories
CREATE POLICY "Users can view their own categories"
    ON expense_categories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own categories"
    ON expense_categories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own categories"
    ON expense_categories FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own categories"
    ON expense_categories FOR DELETE
    USING (auth.uid() = user_id);

-- Políticas para incomes
CREATE POLICY "Users can view incomes of their occasions"
    ON incomes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = incomes.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert incomes to their occasions"
    ON incomes FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = incomes.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

CREATE POLICY "Users can update incomes of their occasions"
    ON incomes FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = incomes.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete incomes of their occasions"
    ON incomes FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = incomes.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

-- Políticas para expenses
CREATE POLICY "Users can view expenses of their occasions"
    ON expenses FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = expenses.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert expenses to their occasions"
    ON expenses FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = expenses.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

CREATE POLICY "Users can update expenses of their occasions"
    ON expenses FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = expenses.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete expenses of their occasions"
    ON expenses FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM occasions 
        WHERE occasions.id = expenses.occasion_id 
        AND occasions.user_id = auth.uid()
    ));

-- Políticas para general_expenses
CREATE POLICY "Users can view their own general expenses"
    ON general_expenses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own general expenses"
    ON general_expenses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own general expenses"
    ON general_expenses FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own general expenses"
    ON general_expenses FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- FUNCIONES RPC
-- ============================================

-- Función para obtener resumen de una ocasión
CREATE OR REPLACE FUNCTION get_occasion_summary(occasion_uuid UUID)
RETURNS TABLE (
    total_income DECIMAL(12, 2),
    total_expense DECIMAL(12, 2),
    profit DECIMAL(12, 2)
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(i.amount), 0) AS total_income,
        COALESCE(SUM(e.amount), 0) AS total_expense,
        COALESCE(SUM(i.amount), 0) - COALESCE(SUM(e.amount), 0) AS profit
    FROM occasions o
    LEFT JOIN incomes i ON i.occasion_id = o.id
    LEFT JOIN expenses e ON e.occasion_id = o.id
    WHERE o.id = occasion_uuid
        AND o.user_id = auth.uid()
    GROUP BY o.id;
END;
$$;

-- Función para obtener resumen general con filtro de fecha
CREATE OR REPLACE FUNCTION get_general_summary(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    total_income DECIMAL(12, 2),
    total_expense DECIMAL(12, 2),
    total_general_expense DECIMAL(12, 2),
    profit DECIMAL(12, 2),
    occasions_count BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH gen_exp_summary AS (
        -- Calculate General Expenses independently first
        SELECT COALESCE(SUM(ge.amount), 0) AS amount
        FROM general_expenses ge
        WHERE ge.user_id = auth.uid()
          AND (start_date IS NULL OR ge.created_at >= start_date)
          AND (end_date IS NULL OR ge.created_at <= end_date)
    )
    SELECT 
        COALESCE(SUM(i.occasion_sum), 0) AS total_income,
        COALESCE(SUM(e.occasion_sum), 0) AS total_expense,
        
        -- Grab the general expense from the CTE
        (SELECT amount FROM gen_exp_summary) AS total_general_expense,

        -- Profit calculation: Income - (Occasion Expenses + General Expenses)
        COALESCE(SUM(i.occasion_sum), 0) 
            - COALESCE(SUM(e.occasion_sum), 0) 
            - (SELECT amount FROM gen_exp_summary) AS profit,

        COUNT(o.id) AS occasions_count
    FROM occasions o
    -- 1. Calculate Income per occasion independently
    LEFT JOIN LATERAL (
        SELECT SUM(amount) as occasion_sum 
        FROM incomes 
        WHERE occasion_id = o.id
    ) i ON TRUE
    -- 2. Calculate Expense per occasion independently
    LEFT JOIN LATERAL (
        SELECT SUM(amount) as occasion_sum 
        FROM expenses 
        WHERE occasion_id = o.id
    ) e ON TRUE
    WHERE o.user_id = auth.uid()
        AND (start_date IS NULL OR o.created_at >= start_date)
        AND (end_date IS NULL OR o.created_at <= end_date);
END;
$$;

-- Función para obtener ocasiones con sus totales
CREATE OR REPLACE FUNCTION get_occasions_with_totals(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    occasion_date DATE,
    created_at TIMESTAMPTZ,
    total_income DECIMAL(12, 2),
    total_expense DECIMAL(12, 2),
    profit DECIMAL(12, 2)
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $
BEGIN
    RETURN QUERY
    SELECT 
        o.id,
        o.name,
        o.description,
        o.occasion_date,
        o.created_at,
        COALESCE(SUM(i.amount), 0) AS total_income,
        COALESCE(SUM(e.amount), 0) AS total_expense,
        COALESCE(SUM(i.amount), 0) - COALESCE(SUM(e.amount), 0) AS profit
    FROM occasions o
    LEFT JOIN incomes i ON i.occasion_id = o.id
    LEFT JOIN expenses e ON e.occasion_id = o.id
    WHERE o.user_id = auth.uid()
        AND (start_date IS NULL OR o.created_at >= start_date)
        AND (end_date IS NULL OR o.created_at <= end_date)
    GROUP BY o.id, o.name, o.description, o.occasion_date, o.created_at
    ORDER BY o.created_at DESC;
END;
$;

-- Lista de gastos generales del usuario filtrados por fecha
CREATE OR REPLACE FUNCTION get_general_expenses_filtered(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    amount DECIMAL(12,2),
    description TEXT,
    created_at TIMESTAMPTZ,
    category_id UUID,
    category_name TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT 
        ge.id,
        ge.amount,
        ge.description,
        ge.created_at,
        ge.category_id,
        ec.name AS category_name
    FROM general_expenses ge
    LEFT JOIN expense_categories ec ON ec.id = ge.category_id
    WHERE ge.user_id = auth.uid()
      AND (start_date IS NULL OR ge.created_at >= start_date)
      AND (end_date IS NULL OR ge.created_at <= end_date)
    ORDER BY ge.created_at DESC;
$$;

-- Elementos combinados para Home
CREATE OR REPLACE FUNCTION get_home_list_elements(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    type TEXT,
    id UUID,
    created_at TIMESTAMPTZ,
    name TEXT,
    description TEXT,
    occasion_date DATE,
    amount DECIMAL(12, 2),
    category_id UUID,
    category_name TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM (
        SELECT 
            'occasion' AS type,
            o.id,
            o.created_at,
            o.name,
            o.description,
            o.occasion_date,
            NULL::DECIMAL(12,2) AS amount,
            NULL::UUID AS category_id,
            NULL::TEXT AS category_name
        FROM occasions o
        WHERE o.user_id = auth.uid()
          AND (start_date IS NULL OR o.created_at >= start_date)
          AND (end_date IS NULL OR o.created_at <= end_date)

        UNION ALL

        SELECT 
            'general_expense' AS type,
            ge.id,
            ge.created_at,
            NULL::TEXT AS name,
            ge.description,
            NULL::DATE AS occasion_date,
            ge.amount,
            ge.category_id,
            ec.name AS category_name
        FROM general_expenses ge
        LEFT JOIN expense_categories ec ON ec.id = ge.category_id
        WHERE ge.user_id = auth.uid()
          AND (start_date IS NULL OR ge.created_at >= start_date)
          AND (end_date IS NULL OR ge.created_at <= end_date)
    ) t
    ORDER BY t.created_at DESC;
$$;
-- ============================================
-- TRIGGERS
-- ============================================


-- Trigger para actualizar updated_at en occasions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_occasions_updated_at
    BEFORE UPDATE ON occasions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Insertar categorías predefinidas (se crearán por usuario al registrarse)
-- Esto debería ejecutarse desde la app al crear un usuario nuevo