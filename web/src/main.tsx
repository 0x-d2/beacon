import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import '@fontsource-variable/geist'
import '@fontsource-variable/geist-mono'
import '@fontsource-variable/inter'
import './styles.css'
import { CatalogProvider, useT } from './data.tsx'
import { Layout } from './ui/Layout.tsx'
import { Overview } from './pages/Overview.tsx'
import { Guide } from './pages/Guide.tsx'
import { Colors } from './pages/Colors.tsx'
import { Typography } from './pages/Typography.tsx'
import { Metrics } from './pages/Metrics.tsx'
import { Materials } from './pages/Materials.tsx'
import { Motion } from './pages/Motion.tsx'
import { Components } from './pages/Components.tsx'
import { ComponentPage } from './pages/ComponentPage.tsx'
import { Surfaces } from './pages/Surfaces.tsx'
import { SurfacePage } from './pages/SurfacePage.tsx'
import { Literals } from './pages/Literals.tsx'
import { Changes } from './pages/Changes.tsx'
import { IOSColors, IOSComponents, IOSScreens } from './pages/IOS.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <CatalogProvider>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Overview />} />
            <Route path="nereden" element={<Guide />} />
            <Route path="renkler" element={<Colors />} />
            <Route path="tipografi" element={<Typography />} />
            <Route path="olculer" element={<Metrics />} />
            <Route path="malzemeler" element={<Materials />} />
            <Route path="hareket" element={<Motion />} />
            <Route path="bilesenler" element={<Components />} />
            <Route path="bilesenler/:category" element={<Components />} />
            <Route path="bilesen/:id" element={<ComponentPage />} />
            <Route path="yuzeyler" element={<Surfaces />} />
            <Route path="yuzeyler/:group" element={<Surfaces />} />
            <Route path="yuzey/:id" element={<SurfacePage />} />
            <Route path="degerler" element={<Literals />} />
            <Route path="degerler/:kind" element={<Literals />} />
            <Route path="degisiklikler" element={<Changes />} />
            <Route path="ios/bilesenler" element={<IOSComponents />} />
            <Route path="ios/ekranlar" element={<IOSScreens />} />
            <Route path="ios/renkler" element={<IOSColors />} />
            <Route path="*" element={<NotFound />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </CatalogProvider>
  </StrictMode>,
)

function NotFound() {
  const t = useT()
  return <div className="page"><h1 className="title">{t('Sayfa yok', 'No such page')}</h1></div>
}
